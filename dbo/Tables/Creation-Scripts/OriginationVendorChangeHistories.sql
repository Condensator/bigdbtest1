SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OriginationVendorChangeHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransferDate] [date] NULL,
	[EffectiveFromDate] [date] NULL,
	[IsCurrent] [bit] NOT NULL,
	[NewOriginationVendorId] [bigint] NULL,
	[NewProgramVendorId] [bigint] NULL,
	[NewRemitToId] [bigint] NULL,
	[OldOriginationVendorId] [bigint] NULL,
	[OldProgramVendorId] [bigint] NULL,
	[OldRemitToId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OldProgramId] [bigint] NULL,
	[NewProgramId] [bigint] NULL,
	[CreditProfileId] [bigint] NULL,
	[OpportunityId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_Contract]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_CreditProfile] FOREIGN KEY([CreditProfileId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_CreditProfile]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_NewOriginationVendor] FOREIGN KEY([NewOriginationVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_NewOriginationVendor]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_NewProgram] FOREIGN KEY([NewProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_NewProgram]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_NewProgramVendor] FOREIGN KEY([NewProgramVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_NewProgramVendor]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_NewRemitTo] FOREIGN KEY([NewRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_NewRemitTo]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_OldOriginationVendor] FOREIGN KEY([OldOriginationVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_OldOriginationVendor]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_OldProgram] FOREIGN KEY([OldProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_OldProgram]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_OldProgramVendor] FOREIGN KEY([OldProgramVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_OldProgramVendor]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_OldRemitTo] FOREIGN KEY([OldRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_OldRemitTo]
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories]  WITH CHECK ADD  CONSTRAINT [EOriginationVendorChangeHistory_Opportunity] FOREIGN KEY([OpportunityId])
REFERENCES [dbo].[Opportunities] ([Id])
GO
ALTER TABLE [dbo].[OriginationVendorChangeHistories] CHECK CONSTRAINT [EOriginationVendorChangeHistory_Opportunity]
GO
